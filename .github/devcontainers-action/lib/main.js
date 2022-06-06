"use strict";
/*--------------------------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
 *-------------------------------------------------------------------------------------------------------------*/
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
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
Object.defineProperty(exports, "__esModule", { value: true });
const core = __importStar(require("@actions/core"));
const utils_1 = require("./utils");
function run() {
    return __awaiter(this, void 0, void 0, function* () {
        core.debug('Reading input parameters...');
        const shouldPublishFeatures = core.getInput('publish-features').toLowerCase() === 'true';
        const shouldPublishTemplate = core.getInput('publish-templates').toLowerCase() === 'true';
        if (shouldPublishFeatures) {
            core.info('Publishing features...');
            const featuresBasePath = core.getInput('base-path-to-features');
            yield packageFeatures(featuresBasePath);
        }
        if (shouldPublishTemplate) {
            core.info('Publishing template...');
            const basePathToDefinitions = core.getInput('base-path-to-templates');
            yield packageTemplates(basePathToDefinitions);
        }
        // TODO: Programatically add feature/template fino with relevant metadata for UX clients.
        core.info('Generation metadata file: devcontainer-collection.json');
        yield (0, utils_1.addCollectionsMetadataFile)();
    });
}
function packageFeatures(basePath) {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            core.info(`Archiving all features in ${basePath}`);
            yield (0, utils_1.getFeaturesAndPackage)(basePath);
            core.info('Packaging features has finished.');
        }
        catch (error) {
            if (error instanceof Error)
                core.setFailed(error.message);
        }
    });
}
function packageTemplates(basePath) {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            core.info(`Archiving all templated in ${basePath}`);
            yield (0, utils_1.getTemplatesAndPackage)(basePath);
            core.info('Packaging templates has finished.');
        }
        catch (error) {
            if (error instanceof Error)
                core.setFailed(error.message);
        }
    });
}
// Kick off execution
run();
