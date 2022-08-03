"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getTemplatesAndPackage = exports.getFeaturesAndPackage = exports.pushCollectionsMetadataToOCI = exports.addCollectionsMetadataFile = exports.getGitHubMetadata = exports.tarDirectory = exports.renameLocal = exports.mkdirLocal = exports.writeLocalFile = exports.readLocalFile = void 0;
const github = __importStar(require("@actions/github"));
const tar = __importStar(require("tar"));
const fs = __importStar(require("fs"));
const core = __importStar(require("@actions/core"));
const child_process = __importStar(require("child_process"));
const util_1 = require("util");
const path_1 = __importDefault(require("path"));
exports.readLocalFile = (0, util_1.promisify)(fs.readFile);
exports.writeLocalFile = (0, util_1.promisify)(fs.writeFile);
exports.mkdirLocal = (0, util_1.promisify)(fs.mkdir);
exports.renameLocal = (0, util_1.promisify)(fs.rename);
// Filter what gets included in the tar.c
const filter = (file, _) => {
    // Don't include the archive itself.
    if (file === './devcontainer-features.tgz') {
        return false;
    }
    return true;
};
function tarDirectory(path, tgzName) {
    return __awaiter(this, void 0, void 0, function* () {
        return tar.create({ file: tgzName, C: path, filter }, ['.']).then(_ => {
            core.info(`Compressed ${path} directory to file ${tgzName}`);
        });
    });
}
exports.tarDirectory = tarDirectory;
function getGitHubMetadata() {
    // Insert github repo metadata
    const ref = github.context.ref;
    let sourceInformation = {
        owner: github.context.repo.owner,
        repo: github.context.repo.repo,
        ref,
        sha: github.context.sha
    };
    // Add tag if parseable
    if (ref.includes('refs/tags/')) {
        const tag = ref.replace('refs/tags/', '');
        sourceInformation = Object.assign(Object.assign({}, sourceInformation), { tag });
    }
    return sourceInformation;
}
exports.getGitHubMetadata = getGitHubMetadata;
function tagFeatureAtVersion(featureMetaData) {
    return __awaiter(this, void 0, void 0, function* () {
        const featureId = featureMetaData.id;
        const featureVersion = featureMetaData.version;
        const tagName = `${featureId}_v${featureVersion}`;
        // Get GITHUB_TOKEN from environment
        const githubToken = process.env.GITHUB_TOKEN;
        if (!githubToken) {
            core.setFailed('GITHUB_TOKEN environment variable is not set.');
            return;
        }
        // Setup Octokit client
        const octokit = github.getOctokit(githubToken);
        // Use octokit to get all tags for this repo
        const tags = yield octokit.rest.repos.listTags({
            owner: github.context.repo.owner,
            repo: github.context.repo.repo
        });
        // See if tags for this release was already created.
        const tagExists = tags.data.some(tag => tag.name === tagName);
        if (tagExists) {
            core.info(`Tag ${tagName} already exists. Skipping...`);
            return;
        }
        // Create tag
        const createdTag = yield octokit.rest.git.createTag({
            tag: tagName,
            message: `Feature ${featureId} version ${featureVersion}`,
            object: github.context.sha,
            type: 'commit',
            owner: github.context.repo.owner,
            repo: github.context.repo.repo
        });
        if (createdTag.status === 201) {
            core.info(`Tagged '${tagName}'`);
        }
        else {
            core.setFailed(`Failed to tag '${tagName}'`);
            return;
        }
        // Create reference to tag
        const createdRef = yield octokit.rest.git.createRef({
            owner: github.context.repo.owner,
            repo: github.context.repo.repo,
            ref: `refs/tags/${tagName}`,
            sha: createdTag.data.sha
        });
        if (createdRef.status === 201) {
            core.info(`Created reference for '${tagName}'`);
        }
        else {
            core.setFailed(`Failed to reference of tag '${tagName}'`);
            return;
        }
    });
}
function addCollectionsMetadataFile(featuresMetadata, templatesMetadata, opts) {
    return __awaiter(this, void 0, void 0, function* () {
        const p = path_1.default.join('.', 'devcontainer-collection.json');
        const sourceInformation = getGitHubMetadata();
        const metadata = {
            sourceInformation,
            features: featuresMetadata || [],
            templates: templatesMetadata || []
        };
        // Write to the file
        yield (0, exports.writeLocalFile)(p, JSON.stringify(metadata, undefined, 4));
        if (opts.shouldPublishToOCI) {
            pushCollectionsMetadataToOCI(p);
        }
    });
}
exports.addCollectionsMetadataFile = addCollectionsMetadataFile;
function pushArtifactToOCI(version, featureName, artifactPath) {
    return __awaiter(this, void 0, void 0, function* () {
        const exec = (0, util_1.promisify)(child_process.exec);
        const versions = [version, '1.0', '1']; // TODO: don't hardcode ofc.
        const sourceInfo = getGitHubMetadata();
        yield Promise.all(versions.map((v) => __awaiter(this, void 0, void 0, function* () {
            const ociRepo = `${sourceInfo.owner}/${sourceInfo.repo}/${featureName}:${v}`;
            try {
                const cmd = `oras push ghcr.io/${ociRepo} \
                    --manifest-config /dev/null:application/vnd.devcontainers \
                                ./${artifactPath}:application/vnd.devcontainers.layer.v1+tar`;
                yield exec(cmd);
                core.info(`Pushed artifact to '${ociRepo}'`);
            }
            catch (error) {
                if (error instanceof Error)
                    core.setFailed(`Failed to push '${ociRepo}':  ${error.message}`);
            }
        })));
    });
}
function pushCollectionsMetadataToOCI(collectionJsonPath) {
    return __awaiter(this, void 0, void 0, function* () {
        const exec = (0, util_1.promisify)(child_process.exec);
        const sourceInfo = getGitHubMetadata();
        const ociRepo = `${sourceInfo.owner}/${sourceInfo.repo}:latest`;
        try {
            const cmd = `oras push ghcr.io/${ociRepo} \
            --manifest-config /dev/null:application/vnd.devcontainers \
                        ./${collectionJsonPath}:application/vnd.devcontainers.collection.layer.v1+json`;
            yield exec(cmd);
            core.info(`Pushed collection metadata to '${ociRepo}'`);
        }
        catch (error) {
            if (error instanceof Error)
                core.setFailed(`Failed to push collection metadata '${ociRepo}':  ${error.message}`);
        }
    });
}
exports.pushCollectionsMetadataToOCI = pushCollectionsMetadataToOCI;
function loginToGHCR() {
    return __awaiter(this, void 0, void 0, function* () {
        const exec = (0, util_1.promisify)(child_process.exec);
        // Get GITHUB_TOKEN from environment
        const githubToken = process.env.GITHUB_TOKEN;
        if (!githubToken) {
            core.setFailed('GITHUB_TOKEN environment variable is not set.');
            return;
        }
        try {
            yield exec(`oras login ghcr.io -u USERNAME -p ${githubToken}`);
            core.info('Oras logged in successfully!');
        }
        catch (error) {
            if (error instanceof Error)
                core.setFailed(` Oras login failed!`);
        }
    });
}
function getFeaturesAndPackage(basePath, opts) {
    return __awaiter(this, void 0, void 0, function* () {
        const { shouldPublishToNPM, shouldTagIndividualFeatures, shouldPublishReleaseArtifacts, shouldPublishToOCI } = opts;
        const featureDirs = fs.readdirSync(basePath);
        let metadatas = [];
        const exec = (0, util_1.promisify)(child_process.exec);
        if (shouldPublishToOCI) {
            yield loginToGHCR();
        }
        yield Promise.all(featureDirs.map((f) => __awaiter(this, void 0, void 0, function* () {
            var _a;
            core.info(`feature ==> ${f}`);
            if (!f.startsWith('.')) {
                const featureFolder = path_1.default.join(basePath, f);
                const featureJsonPath = path_1.default.join(featureFolder, 'devcontainer-feature.json');
                if (!fs.existsSync(featureJsonPath)) {
                    core.error(`Feature '${f}' is missing a devcontainer-feature.json`);
                    core.setFailed('All features must have a devcontainer-feature.json');
                    return;
                }
                const featureMetadata = JSON.parse(fs.readFileSync(featureJsonPath, 'utf8'));
                if (!featureMetadata.id || !featureMetadata.version) {
                    core.error(`Feature '${f}' is must defined an id and version`);
                    core.setFailed('Incomplete devcontainer-feature.json');
                }
                metadatas.push(featureMetadata);
                const sourceInfo = getGitHubMetadata();
                if (!sourceInfo.owner) {
                    core.setFailed('Could not determine repository owner.');
                    return;
                }
                const archiveName = `${f}.tgz`;
                // ---- PUBLISH RELEASE ARTIFACTS (classic method) ----
                if (shouldPublishReleaseArtifacts || shouldPublishToOCI) {
                    core.info(`** Tar'ing feature`);
                    yield tarDirectory(featureFolder, archiveName);
                }
                // ---- PUBLISH TO NPM ----
                if (shouldPublishToOCI) {
                    core.info(`** Publishing to OCI`);
                    // TODO: CHECK IF THE FEATURE IS ALREADY PUBLISHED UNDER GIVEN TAG
                    yield pushArtifactToOCI(featureMetadata.version, f, archiveName);
                }
                // ---- TAG INDIVIDUAL FEATURES ----
                if (shouldTagIndividualFeatures) {
                    core.info(`** Tagging individual feature`);
                    yield tagFeatureAtVersion(featureMetadata);
                }
                // ---- PUBLISH TO NPM ----
                if (shouldPublishToNPM) {
                    core.info(`** Publishing to NPM`);
                    // Adds a package.json file to the feature folder
                    const packageJsonPath = path_1.default.join(featureFolder, 'package.json');
                    // if (!sourceInfo.tag) {
                    //     core.error(`Feature ${f} is missing a tag! Cannot publish to NPM.`);
                    //     core.setFailed('All features published to NPM must be tagged with a version');
                    // }
                    const packageJsonObject = {
                        name: `@${sourceInfo.owner}/${f}`,
                        version: featureMetadata.version,
                        description: `${(_a = featureMetadata.description) !== null && _a !== void 0 ? _a : 'My cool feature'}`,
                        author: `${sourceInfo.owner}`,
                        keywords: ['devcontainer-features']
                    };
                    yield (0, exports.writeLocalFile)(packageJsonPath, JSON.stringify(packageJsonObject, undefined, 4));
                    core.info(`Feature Folder is: ${featureFolder}`);
                    // Run npm pack, which 'tars' the folder
                    const packageName = yield exec(`npm pack ./${featureFolder}`);
                    if (packageName.stderr) {
                        core.error(`${packageName.stderr.toString()}`);
                    }
                    const publishOutput = yield exec(`npm publish --access public "${packageName.stdout.trim()}"`);
                    core.info(publishOutput.stdout);
                    if (publishOutput.stderr) {
                        core.error(`${publishOutput.stderr}`);
                    }
                }
            }
        })));
        if (metadatas.length === 0) {
            core.setFailed('No features found');
            return;
        }
        return metadatas;
    });
}
exports.getFeaturesAndPackage = getFeaturesAndPackage;
function getTemplatesAndPackage(basePath) {
    return __awaiter(this, void 0, void 0, function* () {
        const templateDirs = fs.readdirSync(basePath);
        let metadatas = [];
        yield Promise.all(templateDirs.map((t) => __awaiter(this, void 0, void 0, function* () {
            core.info(`template ==> ${t}`);
            if (!t.startsWith('.')) {
                const templateFolder = path_1.default.join(basePath, t);
                const archiveName = `devcontainer-template-${t}.tgz`;
                // await tarDirectory(templateFolder, archiveName);
                const templateJsonPath = path_1.default.join(templateFolder, 'devcontainer-template.json');
                if (!fs.existsSync(templateJsonPath)) {
                    core.error(`Template '${t}' is missing a devcontainer-template.json`);
                    core.setFailed('All templates must have a devcontainer-template.json');
                    return;
                }
                const templateMetadata = JSON.parse(fs.readFileSync(templateJsonPath, 'utf8'));
                metadatas.push(templateMetadata);
            }
        })));
        if (metadatas.length === 0) {
            core.setFailed('No templates found');
            return;
        }
        return metadatas;
    });
}
exports.getTemplatesAndPackage = getTemplatesAndPackage;
